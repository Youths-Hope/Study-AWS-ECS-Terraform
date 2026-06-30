import logging
from flask import Flask, render_template, request, redirect

from db import (
    get_users,
    get_user,
    insert_user,
    update_user,
    delete_user,
)
from s3_utils import upload_image, delete_image

app = Flask(
    __name__,
    template_folder=""
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

@app.route("/")
def index():
    return "Hello Flask"

@app.route("/form")
def form():
    logging.info("GET /form");
    return render_template("form.html")

@app.route("/users")
def users():
    logging.info("GET /users")

    try:
        results = get_users()

        return render_template(
            "users.html",
            users=results
        )

    except Exception:
        logging.exception("SELECT Error")
        return "DB Error", 500

@app.route("/add", methods=["POST"])
def add_user():
    name = request.form.get("name")
    email = request.form.get("email")
    image = request.files.get("image")

    logging.info(f"POST /add name={name} email={email}")

    try:
        image_url = None
        if image and image.filename:
            image_url = upload_image(image)

        insert_user(name, email, image_url)

    except Exception:
        logging.exception("INSERT Error")
        return "DB Error", 500

    return redirect("/users")

@app.route("/edit/<int:id>")
def edit(id):
    logging.info(f"GET /edit/{id}")

    try:
        user = get_user(id)

        if user is None:
            return "User not found", 404

        return render_template(
            "edit.html",
            user=user
        )

    except Exception:
        logging.exception("SELECT Error")
        return "DB Error", 500

@app.route("/update/<int:id>", methods=["POST"])
def update(id):
    name = request.form.get("name")
    email = request.form.get("email")

    logging.info(f"POST /update name={name} email={email}")

    try:
        update_user(id, name, email)

    except Exception:
        logging.exception("UPDATE Error")
        return "DB Error", 500

    return redirect("/users")

@app.route("/delete/<int:id>", methods=["POST"])
def delete(id):
    logging.info(f"POST /delete id={id}")

    try:
        user = get_user(id)

        if user is None:
            return "User not found", 404

        image_url = user["image_url"]

        if image_url:
            delete_image(image_url)

        delete_user(id)

    except Exception:
        logging.exception("DELETE Error")
        return "DELETE Error", 500

    return redirect("/users")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)