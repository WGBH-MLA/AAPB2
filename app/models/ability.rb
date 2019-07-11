class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCore

    can :play, PBCore do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) || # Comment out for developing TOS features.
        (user.usa? && !user.bot? && (user.affirmed_tos? || user.authorized_referer?) && pbcore.public?)
    end

    cannot :skip_tos, PBCore do |pbcore|
      # We handle international requests elsewhere and if pbcore is private
      # we do not need to show TOS because they won't get the media
      !user.onsite? && # Comment out for developing TOS features.
        !user.affirmed_tos? && user.usa? && !user.bot? && pbcore.public?
    end

    can :access_media_url, PBCore do |pbcore|
      user.onsite? || user.aapb_referer? || user.embed? || (user.authorized_referer? && pbcore.public?)
    end

    # TODO: guessing that api transcript access logic should follow ui logic (so remove this), but need to confirm
    can :api_access_transcript, PBCore do |pbcore|
      user.onsite? || # Comment out for developing TOS features.
        (pbcore.transcript_status == PBCore::CORRECT_TRANSCRIPT || ([PBCore::CORRECTING_TRANSCRIPT, PBCore::UNCORRECTED_TRANSCRIPT] && pbcore.public?))
    end

    can :access_transcript, PBCore do |pbcore|
      user.onsite? || pbcore.public?
    end
  end
end
