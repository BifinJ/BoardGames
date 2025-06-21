import os
import faiss
import google.generativeai as genai
from sklearn.preprocessing import normalize
import re
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
gemini_api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=gemini_api_key)

# Available game list (scanned once)
RULES_DIR = "rules"
available_games = [f.replace(".txt", "") for f in os.listdir(RULES_DIR) if f.endswith(".txt")]

# Cache to hold loaded game data (only when needed)
game_data = {}

# Lazy-load the embedding model
def get_embedding_model():
    from sentence_transformers import SentenceTransformer
    return SentenceTransformer('all-MiniLM-L6-v2')  # or 'paraphrase-MiniLM-L3-v2' for lower memory

# Lazy-load Gemini model
def get_gemini_model():
    return genai.GenerativeModel("gemini-2.0-flash-thinking-exp-01-21")

# Load a specific game's rule data and embed it
def load_game(game_name):
    filename = f"{game_name}.txt"
    filepath = os.path.join(RULES_DIR, filename)
    if not os.path.exists(filepath):
        return None

    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    pattern = r"(?:^|\n)(#+ .+)"
    parts = re.split(pattern, text)
    chunks = []

    for i in range(1, len(parts), 2):
        header = parts[i].strip()
        content = parts[i + 1].strip() if i + 1 < len(parts) else ""
        combined = f"{header}\n{content}"
        if combined.strip():
            chunks.append(combined)

    embedding_model = get_embedding_model()
    embeddings = embedding_model.encode(chunks)
    embeddings = normalize(embeddings)

    dim = embeddings.shape[1]
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings)

    return {"chunks": chunks, "index": index}

# Perform FAISS search
def search_chunks(game, query, k=3):
    if game not in game_data:
        game_data[game] = load_game(game)
    data = game_data.get(game)
    if not data:
        return []

    embedding_model = get_embedding_model()
    query_emb = embedding_model.encode([query])
    query_emb = normalize(query_emb)
    distances, indices = data["index"].search(query_emb, k)

    return [data["chunks"][i] for i in indices[0]]

# Gemini LLM query
def gemini_query(query, context):
    prompt = f"Context:\n{context}\n\nQuestion: {query}\n\nPlease provide a clear and concise answer based on the context."
    try:
        model = get_gemini_model()
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        return f"Error from Gemini: {e}"

# Query answer
def answer_query(game, query, use_llm=True):
    chunks = search_chunks(game, query, k=3)
    if not chunks:
        return "No relevant sections found."

    context = "\n\n".join(chunks)
    if use_llm and gemini_api_key:
        return gemini_query(query, context)
    else:
        return chunks[0][:300] + ("..." if len(chunks[0]) > 300 else "")

# CLI main loop
if __name__ == "__main__":
    print("Welcome to the Game Rules Assistant!")
    print("Available games:", ", ".join(available_games))

    while True:
        game = input("\nEnter game name (or 'exit' to quit): ").strip().lower()
        if game == "exit":
            break
        if game not in available_games:
            print("Game not found. Please try again.")
            continue

        while True:
            query = input(f"\nYour question about {game} (or type 'change' to change game): ").strip()
            if query.lower() == "change":
                break

            use_llm_input = input("Use LLM for a more polished answer? (y/n): ").strip().lower()
            use_llm = use_llm_input == "y"

            answer = answer_query(game, query, use_llm)
            print("\nAnswer:\n", answer)

__all__ = ["load_game", "answer_query", "game_data"]