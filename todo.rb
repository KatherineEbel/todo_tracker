require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  # return error message if list name invalid
  def error_for_list_name(name)
    if !(1..100).cover? name.size
       "List name must be between 1 and 100 characters."
    elsif session[:lists].any? { |list| list[:name] == name }
       "The list #{name} already exists."
    end
  end

  def error_for_todo(name)
    if !(1..100).cover? name.size
       "Todo must be between 1 and 100 characters."
    end
  end

  def todos_count(list)
    list[:todos].size
  end

  def list_completed?(list)
    todos_count(list) > 0 &&
      list[:todos].all? { |todo| todo[:completed] }
  end

  def display_completed_todos(list)
    completed = list[:todos].inject(0) {|sum, todo| todo[:completed] == true ? sum + 1 : sum + 0 }
    "#{completed} / #{todos_count(list)}"
  end

  def list_class(list)
    "complete" if list_completed? list
  end

  def sort_completed(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  def load_list(index)
    list = session[:lists][index] if index
    return list if list
    session[:error] = "The requested list was not found"
    redirect "/lists"
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name list_name
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list #{list_name} has been created."
    redirect "/lists"
  end
end

# /Display a list's todos
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list @list_id
  erb :list, layout: :layout
end

# Edit existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list id
  @name = @list[:name]
  erb :edit_list, layout: :layout
end

# Update existing todo list
post "/lists/:id" do
  new_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = load_list @list_id
  error = error_for_list_name new_name
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = new_name
    session[:success] = "The list has been successfully changed."
    redirect "/lists/#{@list_id}"
  end
end

# delete list
post "/lists/:id/delete" do
  @list_id = params[:id].to_i
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:lists].delete_at(@list_id)[:name]
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end 
end

# add new todo
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo was added to your list."
    redirect "/lists/#{@list_id}"
  end
end

#delete a todo from list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list @list_id
  todo_id = params[:id].to_i
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204 
  else
    session[:success] = "#{@list[:todos].delete_at(todo_id)[:name] } has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

# update todo status
post "/lists/:list_id/todos/:id/" do
  @list_id = params[:list_id].to_i
  @list = load_list @list_id
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "#{@list[:todos][todo_id][:name]} has been successfully updated."
  redirect "/lists/#{@list_id}"
end

# mark all todos complete for list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list @list_id
  @list[:todos].map { |todo| todo[:completed] = true }
  session[:success] = "#{@list[:name]} has been completed."
  redirect "/lists/#{@list_id}"
end
