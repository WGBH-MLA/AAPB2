class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore
    if user.bot?
      # no access
    elsif user.onsite?
      # TODO: These are the settings we want long term:
#      can :play, PBCore, public?: true
#      can :play, PBCore, protected?: true
      # TODO: These are just for testing:
      if user.affirmed_tos?
        can :play, PBCore, public?: true
        can :play, PBCore, protected?: true
      else
        cannot :skip_tos, PBCore
      end  
    elsif user.usa?
      # TODO: Uncomment when we are ready to go live:
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
