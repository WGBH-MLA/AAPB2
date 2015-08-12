class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore

    can :play, PBCore do |pbcore|
      user.onsite? && user.affirmed_tos? && (pbcore.public? || pbcore.protected?)
    end

    # TODO:
#    can :play, PBCore do |pbcore|
#      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
#      (user.usa? && user.affirmed_tos? && pbcore.public?)
#    end

    cannot :skip_tos, PBCore do |pbcore|
      user.onsite? && !user.affirmed_tos? && (pbcore.public? || pbcore.protected?)
    end
 
    # TODO:
#    cannot :skip_tos, PBCore do |pbcore|
#      user.usa? && !user.affirmed_tos? && pbcore.public?
#    end
  end
end
