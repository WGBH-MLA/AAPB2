class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore
    if user.bot?
      # no access
    elsif user.onsite?
      can :play, PBCore, public?: true
      can :play, PBCore, protected?: true
    elsif user.usa?
      # TODO: implement TOS
#      if user.affirmed_tos?
#        can :play, PBCore, public?: true
#      else
#        cannot :skip_tos, PBCore
#      end
    else # international
      # no access
    end
  end
end
