# dockerfile with miniconda3 base image
FROM continuumio/miniconda3

WORKDIR /temp_data

# Create the environment:
COPY environment.yml .
RUN conda env create --name test --file environment.yml

# Make RUN commands use the new environment:
RUN echo "conda activate myenv" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Demonstrate the environment is activated:
RUN echo "Make sure numpy is installed:"
RUN python -c "import numpy"

# The code to run when container is started:
COPY . .
ENTRYPOINT ["./setup.sh"]

