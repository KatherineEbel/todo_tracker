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
  
  def next_element_id(element)
    max = element.map { |list| list[:id] }.max || 0
    max + 1
  end

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

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)  
    complete_todos.each(&block)
  end

  def load_list(id)
    list = session[:lists].find { |list| list[:id] == id }
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
    id = next_element_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
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
  id = list_id = params[:id].to_i
  session[:lists].reject! { |list| list[:id] == id }
  session[:success] = "The list has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end 
end

# add new todo
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }
    session[:success] = "The todo was added to your list."
    redirect "/lists/#{@list_id}"
  end
end

#delete a todo from list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list @list_id
  todo_id = params[:id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id } 
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    session[:success] = "The todo has been deleted"
    status 204 
  else
    session[:success] = "The todo has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

# update todo status
post "/lists/:list_id/todos/:id/" do
  @list_id = params[:list_id].to_i
  @list = load_list @list_id
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  session[:success] = "#{todo[:name]} has been successfully updated."
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
