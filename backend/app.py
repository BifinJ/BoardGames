from flask import Flask, request, jsonify
import os
from main import load_game, answer_query, game_data

app = Flask(__name__)

# Rules directory
RULES_DIR = "rules"

# List available games (from .txt files)
def list_available_games():
    return [f.replace(".txt", "") for f in os.listdir(RULES_DIR) if f.endswith(".txt")]

@app.route("/games", methods=["GET"])
def list_games():
    return jsonify({"games": list_available_games()})

@app.route("/ask", methods=["POST"])
def ask_question():
    data = request.json
    game = data.get("game", "").strip().lower()
    query = data.get("query", "").strip()
    use_llm = data.get("use_llm", True)

    if not game:
        return jsonify({"error": "Game name is required"}), 400
    if not query:
        return jsonify({"error": "Query is required"}), 400

    available_games = list_available_games()
    if game not in available_games:
        return jsonify({"error": f"Game '{game}' not found."}), 404

    # Lazy-load game data if not already in memory
    if game not in game_data:
        game_data[game] = load_game(game)

    answer = answer_query(game, query, use_llm)
    return jsonify({"answer": answer})

if __name__ == "__main__":
    app.run()
