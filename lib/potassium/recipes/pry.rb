class Recipes::Pry < Rails::AppBuilder
  def create
    gather_gems(:development, :test) do
      gather_gem('pry-rails')
      gather_gem('pry-byebug')
    end

    template '../assets/.pryrc', '.pryrc'
  end
end
