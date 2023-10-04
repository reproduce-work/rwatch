# Use a base Node image
FROM node:14

ENV SHELL /bin/bash

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose


# Set the working directory
WORKDIR /usr/src/app

# Create package.json file
RUN echo '{ "name": "reproduce-watcher", "version": "1.0.0", "description": "reproduce.work watcher daemon", "main": "index.js", "scripts": { "start": "node index.js" }, "author": "reproduce.work" }' > package.json

# Copy the package-lock.json file (if you have one)
COPY package*.json ./

# Install chokidar-cli for file watching
RUN npm install chokidar-cli

# Copy the rest of the application code
COPY . .

# Create the entrypoint.sh file
RUN echo "#!/bin/bash\n\
trap \"exit\" INT TERM\n\
trap \"kill 0\" EXIT\n\
# Get the files and command from the arguments\n\
FILES=\"\$1\"\n\
COMMAND=\"\$2\"\n\
# Convert comma-separated list to space-separated list\n\
FILES_TO_WATCH=\$(echo \${FILES} | tr ',' ' ')\n\
echo \"Files to Watch: \${FILES_TO_WATCH}\"\n\
echo \"Command: \${COMMAND}\"\n\
\n\
# Use chokidar-cli to watch the files and execute the command when they change\n\
npx chokidar-cli \${FILES_TO_WATCH} -c \"\${COMMAND}\""   > /usr/src/entrypoint.sh


USER root
# Set the entrypoint script as executable
RUN chmod a+x /usr/src/entrypoint.sh
RUN chmod a+x /usr/local/bin/docker-compose
#USER node

# Set the entrypoint script as the default command, so users can pass in filenames and commands as arguments
ENTRYPOINT ["/usr/src/entrypoint.sh"]

#docker run --init -i -v $(pwd):/usr/src/app watcher "reproduce/main.md,reproduce/pubdata.toml,reproduce/latex/template.tex,reproduce/pubdata.toml,reproducible_plot.svg" 'echo "File has changed!"''
#docker run -it -v $(pwd):/usr/src/app watcher "reproduce/main.md" "echo 'File has changed!'"