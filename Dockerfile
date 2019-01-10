# Use an official Python runtime as a parent image
FROM ruby:2.3.8

# Set the working directory to /app
WORKDIR /app

RUN apt-get update 
RUN apt-get install -y default-libmysqlclient-dev
RUN apt-get install -y mysql-client

# Copy the app directory contents into the container at /app
COPY app /app

RUN bundle install

# Make port 4000 available to the world outside this container
EXPOSE 4000

# Define environment variable
ENV BUILDTYPE docker

# Run app.py when the container launches
#CMD ["rake db:create db:migrate baby:create_defaults && ruby server.rb"]
CMD ["rake", "db:create", "db:migrate", "baby:create_defaults", "puma:start"]
