from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "Netmaker Terraform Web GUI (expand this later!)"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
