FROM python:3.9-slim-buster

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 scrapperuser

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .

# Change ownership of app directory
RUN chown -R scrapperuser:scrapperuser /app

# Switch to non-root user
USER scrapperuser

CMD ["python", "main.py"]