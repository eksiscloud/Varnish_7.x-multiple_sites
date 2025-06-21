#!/usr/bin/env python3

import os
import re
import sys
import json
import httpx
import tempfile
import configparser
from langdetect import detect
from pydub import AudioSegment
from openai import OpenAI
import boto3
# apt instal ffmpeg

# Read config.ini
config = configparser.ConfigParser()
config.read("config.ini")

# Settings
OPENAI_KEY = config["openai"]["api_key"]
WP_API_URL = config["wordpress"]["api_url"]
WP_USER = config["wordpress"]["username"]
WP_PASS = config["wordpress"]["app_password"]
S3_BUCKET = config["s3"]["bucket"]
S3_ACCESS_KEY = config["s3"]["access_key"]
S3_SECRET_KEY = config["s3"]["secret_key"]
S3_ENDPOINT = config["s3"]["endpoint_url"]
S3_FOLDER = config["s3"]["folder"]

# Clean the text, but save (at least) Nordic åäö
def sanitize_text(text: str) -> str:
    substitutions = {
        '★': '', '✓': '', '✔': '', '✗': '', '✘': '', '•': '',
        '[↩]': '', '⟦': '', '⟧': '', '[': '', ']': '',
        '–': '-', '—': '-', '…': '...',
        '“': '"', '”': '"', '‘': "'", '’': "'",
        '\u00a0': ' ', '\u200b': '', '\u200c': '', '\u2028': ' ', '\u2029': ' ',
    }
    for orig, repl in substitutions.items():
        text = text.replace(orig, repl)
    return text

# Remove HTML tags
def strip_html_tags(html: str) -> str:
    return re.sub("<[^>]+>", "", html)

# Fetch the article
def fetch_article_content(article_id: int):
    print("🔗 Getting the article from WordPress...")
    url = f"{WP_API_URL}/posts/{article_id}"
    response = httpx.get(url, auth=(WP_USER, WP_PASS))
    response.raise_for_status()
    data = response.json()
    return data["title"]["rendered"], data["content"]["rendered"]

# Creating the audio from pieces (the article must be splitted, OpenAI limit is 4096 chars)
def generate_audio(text: str, output_path: str, voice: str):
    print("🎙️  Creating speech using OpenAI TTS...")
    client = OpenAI(api_key=OPENAI_KEY)
    max_len = 4096
    chunks = [text[i:i+max_len] for i in range(0, len(text), max_len)]
    audio_segments = []

    for idx, chunk in enumerate(chunks):
        print(f"🧩 Generating part {idx+1}/{len(chunks)}...")
        response = client.audio.speech.create(
            model="tts-1",
            voice=voice,
            input=chunk
        )
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_mp3:
            temp_mp3.write(response.content)
            segment = AudioSegment.from_file(temp_mp3.name, format="mp3")
            audio_segments.append(segment)
        os.unlink(temp_mp3.name)

    print("🔗 Connecting MP3 pieces...")
    combined = sum(audio_segments)
    combined.export(output_path, format="mp3", bitrate="64k")

# Send to Hetzner S3
def upload_to_s3(local_path: str, filename: str) -> str:
    print("☁️ Loading up to Hetzner S3..")
    s3 = boto3.client("s3",
        endpoint_url=S3_ENDPOINT,
        aws_access_key_id=S3_ACCESS_KEY,
        aws_secret_access_key=S3_SECRET_KEY
    )
    key = f"{S3_FOLDER}/{filename}"
    s3.upload_file(local_path, S3_BUCKET, key,
        ExtraArgs={"ACL": "public-read", "ContentType": "audio/mpeg"})
    return f"{S3_ENDPOINT}/{S3_BUCKET}/{key}"

# Main process
def main(article_id: int):
    print("🧠 Identyfying language and selecting voice...")
    title, raw_html = fetch_article_content(article_id)
    clean_text = sanitize_text(strip_html_tags(raw_html))
    language = detect(clean_text)
    voice = "nova" if language == "en" else "shimmer"

    output_filename = f"{article_id}.mp3"
    output_path = os.path.join(tempfile.gettempdir(), output_filename)

    print(f"🔊 Creating MP3 from article: {title}...")
    generate_audio(clean_text, output_path, voice)

    url = upload_to_s3(output_path, output_filename)
    print(f"✅ Audiofile is ready and loaded up to: {url}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./generate_audio_article.py <article_id>")
        sys.exit(1)
    main(int(sys.argv[1]))
