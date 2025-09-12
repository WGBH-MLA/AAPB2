class Ability
  include CanCan::Ability

  # Disabling because, yes, we know...
  # rubocop:disable Metrics/PerceivedComplexity
  def initialize(user)
    can :skip_tos, PBCorePresenter
    
    can :play, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      pbcore.public? && user.usa? && !user.bot? &&
      (user.affirmed_tos? || user.authorized_referer?)
    end
      
    can :play_embedded, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      pbcore.public? && user.usa? && !user.bot?
    end
      
    cannot :skip_tos, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      !user.affirmed_tos? && user.usa? && !user.bot? &&
      pbcore.public?
    end
      
    can :access_media_url, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      (
        user.aapb_referer? ||
        user.embed? ||
        (user.authorized_referer? && pbcore.public?)
      )
    end
      
    can :api_access_transcript, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      (
        pbcore.transcript_status == PBCorePresenter::CORRECT_TRANSCRIPT ||
        ([PBCorePresenter::CORRECTING_TRANSCRIPT, PBCorePresenter::UNCORRECTED_TRANSCRIPT] && pbcore.public?)
      )
    end
      
    can :access_transcript, PBCorePresenter do |pbcore|
      !pbcore.protected? && !pbcore.private? &&
      pbcore.public? && !pbcore.transcript_status.nil?
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
