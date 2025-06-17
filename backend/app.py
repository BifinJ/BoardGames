from flask import Flask, request, jsonify
from main import load_games, answer_query, game_data

app = Flask(__name__)

# Load game rules on startup
load_games()

@app.route("/games", methods=["GET"])
def list_games():
    return jsonify({"games": list(game_data.keys())})

@app.route("/ask", methods=["POST"])
def ask_question():
    data = request.json
    game = data.get("game", "").lower()
    query = data.get("query", "")
    use_llm = data.get("use_llm", True)

    if game not in game_data:
        return jsonify({"error": "Game not found"}), 404
    if not query:
        return jsonify({"error": "Query is required"}), 400

    answer = answer_query(game, query, use_llm)
    return jsonify({"answer": answer})

if __name__ == "__main__":
    app.run(debug=True)
