# Use an official Python slim image for a lightweight environment
FROM python:3.12-slim-bullseye AS base

# Set environment variables for improved performance and behavior
ENV PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    DEBIAN_FRONTEND=noninteractive

# Set the working directory inside the container
WORKDIR /myapp

# Install system dependencies in one RUN command for efficiency
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev curl && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and group
RUN useradd -m -s /bin/bash myuser

# Create the QR code directory and set proper ownership
RUN mkdir -p /myapp/qr_codes && chown -R myuser:myuser /myapp/qr_codes

# Copy only the requirements.txt file to leverage Docker cache
COPY --chown=myuser:myuser ./requirements.txt /myapp/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Switch back to root user to copy the startup script and set permissions
USER root

# Copy the startup script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch back to non-root user for running the application
USER myuser

# Copy the rest of your application's code as non-root user
COPY --chown=myuser:myuser . /myapp

# Expose the port the FastAPI application will run on
EXPOSE 8000

# Set the default command to run the application
CMD ["/start.sh"]