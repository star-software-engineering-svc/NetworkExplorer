# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

## Requirements

* Ruby 2.7.2.

* Rails 6.0.3.4

* Node.js 10.12+, Npm

* MongoDB.

## Installation
We develop this project on MacOS Catalina(10.15).
### 1. Install Ruby
You can manually change from Bash to ZSH anytime by running the following command:
```shell
chsh -s /bin/zsh
```
First, we need to install Homebrew. Homebrew allows us to install and compile software packages easily from source.
```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
Now that we have Homebrew installed, we can use it to install Ruby.

We are going to use rbenv to install and manage our Ruby versions.

To do this, run the following commands in your Terminal:
```shell
brew install rbenv ruby-build

# Add rbenv to bash so that it loads every time you open a terminal
echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.zshrc
source ~/.zshrc

# Install Ruby
rbenv install 2.7.2
rbenv global 2.7.2
ruby -v
```
If ruby version is not setted as 2.7.2, then you can use following command.
```shell
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```
### Installing Rails
Installing Rails is as simple as running the following command in your Terminal:
```shell
gem install rails -v 6.0.3.4
```
Rails is now installed, but in order for us to use the rails executable, we need to tell rbenv to see it:
```shell
rbenv rehash
```
And now we can verify Rails is installed:
```shell
rails -v
# Rails 6.0.3.4
```
### Installing Nodejs and Npm
To install node.js and npm, you can use brew.
```shell
brew update
brew install node
```
## Configuration
You can set the base url on config/initializers/env.rb
```ruby
# Be sure to restart your server when you modify this file.

ENV['base_url'] = "http://localhost:3000"

```

Now you need to set up the database configuration in config/mongoid.yml.

## Running the server
You can run the following command at the root of code repository.
```shell
rails server
```
Then the server will work at http://localhost:3000
