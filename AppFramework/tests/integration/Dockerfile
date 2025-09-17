FROM python:3.12-slim

WORKDIR /app

# Copy requirements.txt (make sure it's in the right directory)
COPY requirements.txt .

# Install Python dependencies from requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy all test files into the container
COPY pytest.ini .
COPY ./common ./tests/

# Run the tests when the container starts
CMD ["pytest", "--maxfail=2", "--tb=no", "tests/"]