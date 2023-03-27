class Adm::StylesController < AdmController

  after_action { authorize :default_admin, :show? }

  def show
    flash.now[:success] = "This is a success."
    flash.now.notice = "This is a notice."
    flash.now.alert = "This is an alert."
    flash.now[:error] = "This is an error."
  end

  def forms
  end

end
