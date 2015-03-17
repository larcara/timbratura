class AdminMailer < ActionMailer::Base
  default from: "no-reply@camera.it"

  def test_mail(clock)
    mail(to: ["luca.arcara@camera.it"],  body: clock.to_s)
  end

  def confirm_mail(user, message)
    mail(to: user.email, ccn: ["luca.arcara@camera.it"],  subject: "Conferma registrazione", body: message)
  end


  def timesheet(date)
    @user_data={}
    User.where("coalesce(role,'') = ''").each{|x| @user_data[x.username]={check_in: nil, check_in_real_time: nil , check_out: nil, check_out_real_time: nil , check_in_message: nil, check_out_message: nil, check_in_ip: nil, check_out_ip: nil}}
    @user_data["Header"]={check_in: "check_in", check_in_real_time: "check_in_real_time", check_out: "check_out", check_out_real_time: "check_out_real_time",
                          check_in_message: "check_in_message", check_out_message: "check_out_message", check_in_ip: "check_in_ip", check_out_ip: "check_out_ip"}
    Clock.where( date: date).each do |t|
      key=t.user.username
      if @user_data[key]
        @user_data[key][t.action.to_sym] = t.time.localtime
        @user_data[key]["#{t.action}".to_sym] = t.time.localtime
        @user_data[key]["#{t.action}_real_time".to_sym] = t.created_at.localtime
        @user_data[key]["#{t.action}_message".to_sym] = t.message
        @user_data[key]["#{t.action}_ip".to_sym] = t.ip
      end
    end
    mail(to: ["luca.arcara@camera.it", "capcbt_carbonelli@camera.it"])


  end
end
