class Adm::StylesController < AdmController

  after_action { authorize :default_admin, :show? }

  def show
    flash.now[:success] = "This is a success."
    flash.now.notice = "This is a notice."
    flash.now.alert = "This is an alert."
    flash.now[:error] = "This is an error."
    render Views::Adm::Styles::Show.new
  end

  def tiles
    render Views::Adm::Styles::Tiles.new
  end

  def forms
    render Views::Adm::Styles::Forms.new
  end

  def phlex
    render Views::Adm::Styles::Phlex.new
  end

  def items
    render Views::Adm::Styles::Items.new
  end

  def icons
    render Views::Adm::Styles::Icons.new
  end
end
