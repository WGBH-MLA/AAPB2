class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore

    can :play, PBCore do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) || # Comment out for developing TOS features.
        (user.usa? && !user.bot? && (user.affirmed_tos? || user.authorized_referer?) && pbcore.public?)
    end

    cannot :skip_tos, PBCore do |pbcore|
      !user.onsite? && # Comment out for developing TOS features.
        !user.affirmed_tos? && user.usa? && !user.bot? && pbcore.public?
    end

    can :access_media_url, PBCore do |pbcore|
      user.onsite? || user.aapb_referer? || user.embed? || (user.authorized_referer? && pbcore.public?)
    end

    can :access_transcript, PBCore do |pbcore|
      user.onsite? || # Comment out for developing TOS features.
        (pbcore.transcript_status == PBCore::ORR_TRANSCRIPT || (pbcore.transcript_status == PBCore::INDEXING_TRANSCRIPT && pbcore.public?))
    end
  end
end
