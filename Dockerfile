# Use an official Python runtime as a parent image
FROM continuumio/miniconda:4.5.11

# Set the working directory to /run_pyclone
WORKDIR /run_pyclone

# Copy the current directory contents into the container at /app
COPY . /app

# Update Ubuntu Software repository
RUN apt-get update --fix-missing

# Install any needed packages specified in requirements.txt
RUN apt-get install -y r-base-core perl6 && \
        rm -rf /var/lib/apt/lists/*

# Install pyclone
RUN conda install pyclone -c aroth85

CMD [ "/bin/bash" ]
