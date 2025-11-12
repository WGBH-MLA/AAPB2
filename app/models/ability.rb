class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/PerceivedComplexity

  def initialize(user)
    can :skip_tos, PBCorePresenter

    can :play, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
        (
          (
            user.usa? ||
            user.globally_allowed?(pbcore.id)
          ) &&
          !user.bot? &&
          (user.affirmed_tos? || user.authorized_referer?) &&
          pbcore.public?
        )
    end

    can :play_embedded, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
        (
          (
            user.usa? || user.globally_allowed?(pbcore.id)
          ) &&
          !user.bot? &&
          pbcore.public?
        )
    end

    cannot :skip_tos, PBCorePresenter do |pbcore|
      !user.onsite? && !user.affirmed_tos? && user.usa? && !user.bot? && pbcore.public?
    end

    can :access_media_url, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
        ((user.embed? || user.aapb_referer? || user.authorized_referer?) && pbcore.public?)
    end

    can :api_access_transcript, PBCorePresenter do |pbcore|
      !pbcore.private? &&
        (
          user.onsite? ||
          (
            pbcore.public? &&
              [
                PBCorePresenter::CORRECT_TRANSCRIPT,
                PBCorePresenter::CORRECTING_TRANSCRIPT,
                PBCorePresenter::UNCORRECTED_TRANSCRIPT
              ].include?(pbcore.transcript_status)
          )
        )
    end

    can :access_transcript, PBCorePresenter do |pbcore|
      !pbcore.private? &&
        (user.onsite? || pbcore.public?) &&
        !pbcore.transcript_status.nil?
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
