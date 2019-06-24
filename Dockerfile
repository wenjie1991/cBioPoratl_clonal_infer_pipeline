# Use an official Python runtime as a parent image
FROM continuumio/miniconda:4.5.11

# Set the working directory to /run_pyclone
WORKDIR /run_pyclone

# Copy the current directory contents into the container at /app
COPY . /run_pyclone

# Update Ubuntu Software repository
RUN apt-get update --fix-missing

# Install R
RUN apt-get install -y r-base-core perl6 && \
        rm -rf /var/lib/apt/lists/* && \
        Rscript -e 'install.packages("data.table", repos="https://cran.rstudio.com")'

# Install perl6
RUN wget https://github.com/nxadm/rakudo-pkg/releases/download/v2019.03.1/rakudo-pkg-Debian9_2019.03.1-01_amd64.deb && \ 
        dpkg -i *.deb &&
ENV PATH ~/.perl6/bin:/opt/rakudo-pkg/bin:/opt/rakudo-pkg/share/perl6/site/bin:$PATH
RUN zef install YAMLish

# Install pyclone
RUN conda install pyclone -c aroth85

CMD [ "/bin/bash" ]
