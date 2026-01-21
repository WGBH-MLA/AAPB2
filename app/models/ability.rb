class Ability
  include CanCan::Ability

  def initialize(user)
    can :skip_tos, PBCorePresenter do |pbcore|
      can?(:play, pbcore) &&
      !user.bot? &&
      (user.affirmed_tos? || user.authorized_referer?)
    end


    can :play, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?) && user.affirmed_tos?) ||
        (
          (user.usa? || GlobalMedia.allowed?(pbcore.id)) &&
          !user.bot? &&
          (user.affirmed_tos? || user.authorized_referer?) &&
          pbcore.public?
        )
    end

    can :play_embedded, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
        (
          (user.usa? || GlobalMedia.allowed?(pbcore.id)) &&
          !user.bot? &&
          pbcore.public?
        )
    end

    can :access_media_url, PBCorePresenter do |pbcore|
      (user.onsite? && (pbcore.public? || pbcore.protected?)) ||
        ((user.embed? || user.aapb_referer? || user.authorized_referer?) && pbcore.public?)
    end
      
    can [:api_access_transcript, :access_transcript], PBCorePresenter do |pbcore|
      !pbcore.private? && !pbcore.transcript_status.nil?
    end
  end
end
