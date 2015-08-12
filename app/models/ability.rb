class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore

    can :play, PBCore do |pbcore|
      user.onsite? && user.affirmed_tos? && (pbcore.public? || pbcore.protected?)
    end

    cannot :skip_tos, PBCore do |pbcore|
      user.onsite? && !user.affirmed_tos?
    end
  end
end
