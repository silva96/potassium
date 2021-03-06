# The DSL


The DSL to extend and add recipes defines methods divided in mixins called helpers.

## The helpers

- [Templates](#template-helpers)
- [Answers](#answer-helpers)
- [Variable](#variable-helpers)
- [Environment](#environment-helpers)
- [Callback](#callback-helpers)
- [Gem](#gem-helpers)
- [Info](#info-helpers)
- [Readme](#readme-helpers)

### Template Helpers

##### | `ask(recipe_name)`

Loads the recipe and execute its `ask` method.

```ruby
ask :devise
```

##### | `create(recipe_name)`

Loads the recipe and execute its `create` method.

```ruby
create :devise
```

##### | `install(recipe_name)`

Loads the recipe and execute its `install` method. If the recipe implements
a `installed?` method it will check first if it is already installed. You can
force the installation by passing the `--force` argument on the cli.

```ruby
install :devise
```

##### | `load_recipe(recipe_name)`

Loads and return the recipe.

##### | `force?`

Whether the `--force` argument was passed from the cli.

##### | `eval_file(file)`

Just evals a file from the source path of this folder. Example:

```ruby
eval_file('recipes/database.rb')
```

You can use any variable name you want in the body of the recipe because all the code loaded in each recipe is wrapped inside a method that is executed thereafter.

##### | `erase_comments(file)`

Erase the comments from a file in the rails application created. Example:

```ruby
erase_comments('Gemfile')
```

### Answer Helpers

##### | `answer(key, &block)`

Defines a key to store the answers. In the fallback you can pass a block
with the code that will make the question.

```ruby
answer(:devise) do
  Ask.confirm("Do you want to install devise")
end
```

### Variable Helpers

##### | `set(key, value)`

Defines a variable to use in different parts of the template. It's important to note that this was preferred over using standard instance variables because the rails template context is not fully controlled by us and to use arbitrary standard instance variables can lead to name clashing. Example:

```ruby
set('fruit', 'platanus')
```

##### | `get(key)`

Retrieves a variable that was defined with `set`. Example:

```ruby
get('fruit') == 'platanus'
```

##### | `equals?(key, value)`

Wrapps the pattern `get(key) == value`. Example:

```ruby
set('fruit', 'platanus')
equals?('fruit', 'banana') # false
equals?('fruit', 'platanus') # true
```

### Environment Helpers

##### | `set_env(key, value)`

Stores a future environment helper in the key `default_env` to be used in some way (the `.rbenv-vars` file is the only use right now). To help ensure that the execution of some rake commands in the end of the installation is correct, this sets the value as a real environment variable too. In this way, running `rake db:create` within the template will use the same environment variables that will use later, while running. Example:

```ruby
set_env('DB_USER', 'root')
```

##### | `get_env(key)`

Get the previously stored variable stored with `set_env` with the name of the key. Example:

```ruby
get_env('DB_USER')
```

##### | `default_env(hash = {})`

This stores all the pairs of a hash as environment variables. Example:

```ruby
default_env({
  'DB_NAME' => "#{get(:underscorized_app_name)}",
  'DB_USER' => "root",
  'DB_PASSWORD' => ''
})
```

### Callback Helpers

This helpers helps to organize the flow inside the template between multiple recipes. They ensure that the template runs in order and help injecting callbacks before and after important actions. For example, a recipe may want to register something to happen after the gem installation and something to happen after the database creation.

##### | `run_action(action_name, &block)`

Runs a block with the registered callbacks for the action named as the action_name parameter. Example:

```ruby
run_action(:gem_install) do
  build_gemfile
  run "bundle install"
end
```

##### | `after(action_name, wrap_in_action: false, &callback)`

This registers a callback to happen after an action happened. The `wrap_in_action` parameter can be used to wrap the callback in a `run_action` call. Example:

```ruby
# in the template file
run_action(:gem_install) do
  build_gemfile
  run "bundle install"
end

# in another recipe
after(:gem_install) do
  generate "active_admin:install"
end

# or
after(:gem_install, :wrap_in_action => :admin_install) do
  generate "active_admin:install"
end

# that is the same as:
after(:gem_install) do
  run_action(:admin_install) do
    generate "active_admin:install"
  end
end
```

##### | `before(action_name, wrap_in_action: false, &callback)`

This registers a callback to happen after an action happened. The `wrap_in_action` parameter can be used to wrap the callback in a `run_action` call. Example:

```ruby
# in the template file
run_action(:gem_install) do
  build_gemfile
  run "bundle install"
end

before(:gem_install) do
  success "We are going to run gem install now"
end
```

### Gem Helpers

The process with the gems installation is different from the standard Rails one. Instead of using the `gem` method to append the gem information into the Gemfile, we are following a process like this:

1. Replace the Gemfile's content with the only the source.
2. Add the gems required by Rails to a hash in memory with the gems information.
3. Through the loading of the recipes, add gems to the same hash.
4. Using `build_gemfile` we build the gemfile from that information in a way that makes the Gemfile to be clean.

##### | `gather_gem(name, *attributes)`

The attributes are the same as the attributes of the `gem` method of the Rails Templates. This adds a gem to the gem information but doesn't add it to the Gemfile yet. Example:

```ruby
gather_gem 'activeadmin', github: 'activeadmin'
```

##### | `gather_gems(*environments, &block)`

Calls the block inside a block with the specified environments. It adds those gems as gems of those environments, so they are added in the correct place in the Gemfile. Again, everything is in memory and it's just stored in a final step, so we don't repeat groups in the final Gemfile. Example:

```ruby
gather_gems(:development, :test) do
  gather_gem('pry-rails')
end
```

##### | `discard_gem(name)`

This discard a previously added gem from everywhere. Example:

```ruby
discard_gem('sqlite3')
```

##### | `clean_gemfile`

This removes everything from the Gemfile, adds the `source 'https://rubygems.org'` line in the top, reads from the `gemfile_entries` array, which holds the original gems that rails created, and add them to the hash of gems. Example:

```ruby
run_action(:cleaning) do
  clean_gemfile
  # After that, the Gemfile is empty
end
```

##### | `build_gemfile`

It inserts the gems stored in memory inside the Gemfile, filling it cleanly. Example:

```ruby
run_action(:gem_install) do
  build_gemfile
  run "bundle install"
end
```

### Info Helpers

##### | `success(message)`

To show success messages through standard output.

```ruby
success("gem installed!")
```

##### | `error(message)`

To show error messages through standard output.

```ruby
error("error trying to create installation file")
```

##### | `info(message)`

To show info messages through standard output.


```ruby
info("ActiveAdmin is already installed")
```

### Readme Helpers

After running the potassium's `create` command, a custom `README.md` file will be generated with recipes you chose.
Each recipe defines a "chunk" of that file. To do this, first you need to fill the [README.yml](/lib/potassium/assets/README.yml) file with desired definitions. Then, execute one of the following methods:

##### | `add_readme_header(header, iterpolation_values)`

If, for example, you want to add the style guide header, you need to do:

```yml
readme:
  headers:
    style_guide:
      title: "Style Guides"
      body: "The style guides are enforced through a self hosted version of..."
```

Then, in the recipe:

```ruby
add_readme_header(:style_guide)
```

##### | `add_readme_section(header, section, iterpolation_values)`

To add header's sections. Paperclip, for example:

```yml
readme:
  headers:
    internal_dependencies:
      title: "Internal dependencies"
      sections:
        paperclip:
          title: "Uploads"
          body: "For managing uploads, this project uses..."
```

```ruby
add_readme_section(:internal_dependencies, :paperclip)
```
