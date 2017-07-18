module Warehouse
  class BuildReport
    def run!
      Warehouse::CasReport.transaction do
        # Replace all CAS data in the warehouse every time
        Warehouse::CasReport.delete_all
        at = MatchDecisions::Base.arel_table
        ::Client.joins( :project_client, client_opportunity_matches: :decisions ).preload(
          :project_client,
          {
            client_opportunity_matches: {
              decisions: [
                :decline_reason,
                :not_working_with_client_reason,
                :administrative_cancel_reason,
              ],
              opportunity: [voucher: :sub_program],
            }
          }
        ).where( at[:status].not_eq nil ).distinct.find_each do |client|
          client_id = client.project_client.id_in_data_source
          client.client_opportunity_matches.each do |match|
            # similar to match.current_decision, but more efficient given that we've preloaded all the decisions
            decisions = match.decisions.select(&:status).sort_by(&:created_at)
            # Debugging 
            # puts decisions.map{|m| [m[:id], m[:type], m.status, m.label, m.label.blank?]}.uniq.inspect
            sub_program = match.sub_program
            current_decision = decisions.last
            previous_updated_at = nil
            match_started_decision = match.match_recommendation_dnd_staff_decision
            match_started_at = if match_started_decision.status == 'accepted'
              match_started_decision.updated_at
            else
              nil
            end
            contacts = %i(
              client_contacts
              dnd_staff_contacts
              housing_subsidy_admin_contacts
              shelter_agency_contacts
              ssp_contacts
            ).map do |column|
              [
                column,
                # just keep the relevant columns
                match.send(column).map do |contact|
                  contact.attributes.slice(*Contact.exportable_columns).map{ |k,v| [ k, v.presence ] }.to_h
                end
              ]
            end.to_h
            decisions.each_with_index do |decision, idx|
              if previous_updated_at
                elapsed_days = ( decision.updated_at.to_date - previous_updated_at.to_date ).to_i
              end
              # we want to be able to report on wether or not the HSA requested a CORI check
              # so we'll split that step into two
              step_name = decision.step_name
              if decision.type == 'MatchDecisions::ScheduleCriminalHearingHousingSubsidyAdmin'
                if decision.status == 'no_hearing'
                  step_name += ' - no hearing requested'
                elsif decision.status == 'scheduled'
                  step_name += ' - hearing requested'
                end
              end
              Warehouse::CasReport.create!(
                client_id: client_id,
                match_id: match.id,
                decision_id: decision.id,
                decision_order: idx,
                match_step: step_name,
                decision_status: decision.label,
                current_step: decision == current_decision,
                decline_reason: explain( decision, :decline_reason ),
                not_working_with_client_reason: explain( decision, :not_working_with_client_reason ),
                administrative_cancel_reason: explain( decision, :administrative_cancel_reason ),
                active_match: match.active?,
                created_at: decision.created_at,
                updated_at: decision.updated_at,
                elapsed_days: elapsed_days.to_i,
                client_last_seen_date: decision.client_last_seen_date,
                criminal_hearing_date: decision.criminal_hearing_date,
                client_spoken_with_services_agency: decision.client_spoken_with_services_agency,
                cori_release_form_submitted: decision.cori_release_form_submitted,
                match_started_at: match_started_at,
                program_type: sub_program.program_type,
                **contacts
              )
              previous_updated_at = decision.updated_at
            end
          end
        end
      end
    end

    def explain(decision, reason)
      if r = decision.send(reason)
        explanation = r.name
        if r.other?
          explanation = "#{explanation}: #{ decision.send "#{reason}_other_explanation" }"
        end
        explanation
      end
    end
  end
end
