class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore

    # OLD
#    can :play, PBCore do |pbcore|
#      user.onsite? && user.affirmed_tos? && (pbcore.public? || pbcore.protected?)
#    end

    can :play, PBCore do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
      (user.usa? && !user.bot? && user.affirmed_tos? && pbcore.public?)
    end

    # OLD
#    cannot :skip_tos, PBCore do |pbcore|
#      user.onsite? && !user.affirmed_tos? && (pbcore.public? || pbcore.protected?)
#    end

    cannot :skip_tos, PBCore do |pbcore|
      user.usa? && !user.bot? && !user.affirmed_tos? && pbcore.public?
    end

  end
end
