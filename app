from flask import Flask, render_template, request
import pdfplumber
from groq import Groq

app = Flask(__name__)

SYSTEM_PROMPT = """
You are a medical lab report analysis assistant.
Analyze the lab report carefully.
Highlight abnormal values clearly.
Compare with normal medical reference ranges when possible.
Explain findings in simple language.
Suggest whether doctor consultation is needed.
If insufficient data, clearly mention it.

Structure:
🔎 Abnormal Findings:
📖 Explanation:
⚠️ Risk Level:
👨‍⚕️ Doctor Consultation:
"""

def extract_text_from_pdf(file):
    text = ""
    try:
        with pdfplumber.open(file) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
    except Exception as e:
        print("PDF Error:", e)
        return None
    return text

def analyze_report(lab_text):
    try:
        response = client.chat.completions.create(
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": lab_text[:3000]}
            ],
            model="llama-3.1-8b-instant",
            temperature=0.3
        )

        return response.choices[0].message.content

    except Exception as e:
        print("Groq Error:", e)
        return "AI analysis failed. Please try again."


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/about")
def about():
    return render_template("about.html")


@app.route("/login")
def login():
    return render_template("login.html")


@app.route("/analyze", methods=["POST"])
def analyze():
    file = request.files.get("file")

    if not file:
        return render_template("result.html",
                               result="No file uploaded.",
                               risk="medium")

    if not file.filename.lower().endswith(".pdf"):
        return render_template("result.html",
                               result="Upload PDF only.",
                               risk="medium")

    extracted_text = extract_text_from_pdf(file)

    if not extracted_text:
        return render_template("result.html",
                               result="Could not read PDF.",
                               risk="medium")

    ai_response = analyze_report(extracted_text)

    risk = "good"

    if "high" in ai_response.lower() or "critical" in ai_response.lower():
        risk = "high"
    elif "moderate" in ai_response.lower() or "borderline" in ai_response.lower():
        risk = "medium"

    return render_template("result.html",
                           result=ai_response,
                           risk=risk)

if __name__ == "__main__":
    app.run(debug=True)
