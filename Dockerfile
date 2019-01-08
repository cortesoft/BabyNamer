# Use an official Python runtime as a parent image
FROM ruby:2.3.8

# Set the working directory to /app
WORKDIR /app

# Copy the app directory contents into the container at /app
COPY app /app

# Install any needed packages specified in requirements.txt
RUN apt-get update && apt-get install -y default-libmysqlclient-dev
RUN bundle install

# Make port 4000 available to the world outside this container
EXPOSE 4000

# Define environment variable
ENV BUILDTYPE docker

# Run app.py when the container launches
CMD ["rake db:create db:migrate baby:create_defaults && ruby server.rb"]
