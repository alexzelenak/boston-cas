class Role < ActiveRecord::Base
  has_many :user_roles, dependent: :destroy, inverse_of: :role
  has_many :users, through: :user_roles
  validates :name, presence: true
  
  def role_name
    name.to_s.humanize.gsub('Dnd', 'DND').gsub('Hsa', 'HSA')
  end

  def self.permissions
    [
      :can_view_all_clients, 
      :can_edit_all_clients,
      :can_participate_in_matches,
      :can_view_all_matches,
      :can_see_alternate_matches,
      :can_edit_match_contacts,
      :can_approve_matches,
      :can_reject_matches,
      :can_act_on_behalf_of_match_contacts,
      :can_view_reports, 
      :can_edit_roles, 
      :can_edit_users, 
      :can_view_full_ssn, 
      :can_view_full_dob,  
      :can_view_buildings, 
      :can_edit_buildings, 
      :can_view_funding_sources, 
      :can_edit_funding_sources, 
      :can_view_subgrantees, 
      :can_edit_subgrantees, 
      :can_view_vouchers, 
      :can_edit_vouchers, 
      :can_view_programs, 
      :can_edit_programs, 
      :can_view_opportunities, 
      :can_edit_opportunities, 
      :can_reissue_notifications, 
      :can_view_units, 
      :can_edit_units, 
      :can_add_vacancies,
      :can_view_contacts,
      :can_edit_contacts,
      :can_view_rule_list,
      :can_edit_rule_list,
      :can_view_available_services,
      :can_edit_available_services,
      :can_assign_services,
      :can_assign_requirements,
    ]
  end
end