from flask import Flask, request, jsonify, send_from_directory
import os
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
API_KEY = os.getenv("API_KEY")

@app.before_request
def before_request():
    # Skip authentication for health and readiness endpoints
    if request.path in ['/healthz', '/readyz']:
        return
        
    # Skip authentication for OPTIONS requests (needed for CORS)
    if request.method == 'OPTIONS':
        return
    
    # Get the API key from headers
    key = request.headers.get("X-API-Key")
    if key != API_KEY:
        logger.warning(f"Unauthorized access attempt from {request.remote_addr}")
        return "Unauthorized", 403

@app.route("/upload", methods=["POST"])
def upload_file():
    if 'file' not in request.files:
        logger.warning("Upload attempt with no file")
        return "No file", 400
    file = request.files['file']
    filepath = os.path.join(UPLOAD_DIR, file.filename)
    file.save(filepath)
    logger.info(f"File uploaded successfully: {file.filename}")
    return "Uploaded", 200

@app.route("/files")
def list_files():
    files = os.listdir(UPLOAD_DIR)
    logger.info(f"Listing {len(files)} files")
    return jsonify(files)

@app.route("/files/<filename>")
def serve_file(filename):
    logger.info(f"Serving file: {filename}")
    return send_from_directory(UPLOAD_DIR, filename)

@app.route("/healthz")
def health():
    logger.debug("Health check")
    return "OK", 200

@app.route("/readyz")
def ready():
    logger.debug("Readiness check")
    return "OK", 200

if __name__ == "__main__":
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    logger.info(f"Starting server with API key: {API_KEY[:4] if API_KEY else 'None'}...")
    app.run(host="0.0.0.0", port=8080)
