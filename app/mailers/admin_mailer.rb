class AdminMailer < ActionMailer::Base
  default :from => "speakerInnen@gmail.com"

  def new_profile_confirmed(profile)
    @profile = profile
    @url  = 'https://github.com/rubymonsters/speakerinnen_liste/wiki/Approve-new-Speakerinnen*-so-they-get-published'
    mail(to: 'maren.heltsche@gmail.com', subject: 'Publish new Speakerinnen Profile')
  end

  def profile_published(profile)
    @profile = profile
    @url = "www.speakerinnen.org"
    mail(to: @profile.email, subject: 'Your are now published on the Speakerinnen-Website')
  end

end
