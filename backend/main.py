import os
import faiss
import google.generativeai as genai
from sklearn.preprocessing import normalize
from sentence_transformers import SentenceTransformer
from langchain.text_splitter import CharacterTextSplitter
from dotenv import load_dotenv
import re

# Load environment variables
load_dotenv()
gemini_api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=gemini_api_key)

# LLM Model
gemini_model = genai.GenerativeModel("gemini-2.0-flash-thinking-exp-01-21")

# Embedding model
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

# Dictionary to store FAISS index and chunks for each game
game_data = {}

# Load rule files from the 'rules/' directory
def load_games(rules_dir="rules"):
    for filename in os.listdir(rules_dir):
        if filename.endswith(".txt"):
            game_name = filename.replace(".txt", "")
            filepath = os.path.join(rules_dir, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                text = f.read()

            # Split based on markdown-style headers
            pattern = r"(?:^|\n)(#+ .+)"
            parts = re.split(pattern, text)
            chunks = []

            # Recombine headers and their content
            for i in range(1, len(parts), 2):
                header = parts[i].strip()
                content = parts[i + 1].strip() if i + 1 < len(parts) else ""
                combined = f"{header}\n{content}"
                if len(combined.strip()) > 0:
                    chunks.append(combined)

            # Generate and normalize embeddings
            embeddings = embedding_model.encode(chunks)
            embeddings = normalize(embeddings)

            # Create FAISS index
            dim = embeddings.shape[1]
            index = faiss.IndexFlatL2(dim)
            index.add(embeddings)

            # Store
            game_data[game_name] = {"chunks": chunks, "index": index}
    print(f"Loaded games: {list(game_data.keys())}")

# Gemini query (optional)
def gemini_query(query, context):
    prompt = f"Context:\n{context}\n\nQuestion: {query}\n\nPlease provide a clear and concise answer based on the context."
    try:
        response = gemini_model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        return f"Error from Gemini: {e}"

# Search top-k chunks
def search_chunks(game, query, k=3):
    data = game_data.get(game)
    if not data:
        return []

    chunks = data["chunks"]
    index = data["index"]

    query_emb = embedding_model.encode([query])
    query_emb = normalize(query_emb)
    distances, indices = index.search(query_emb, k)

    return [chunks[i] for i in indices[0]]

# Answer the query
def answer_query(game, query, use_llm=True):
    chunks = search_chunks(game, query, k=3)
    context = "\n\n".join(chunks)

    if use_llm and gemini_api_key:
        return gemini_query(query, context)
    else:
        # Use the top-1 section and return the first ~300 characters
        concise = chunks[0][:300] + ("..." if len(chunks[0]) > 300 else "")
        return f"{concise}"

# Main loop
if __name__ == "__main__":
    load_games()

    print("Welcome to the Game Rules Assistant!")
    print(f"Available games: {', '.join(game_data.keys())}")

    while True:
        game = input("\nEnter game name (or 'exit' to quit): ").strip().lower()
        if game == "exit":
            break
        if game not in game_data:
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
