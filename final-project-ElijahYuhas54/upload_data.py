import firebase_admin
from firebase_admin import credentials, firestore
import json
from datetime import datetime

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Load the generated data
with open('workout_dataset.json', 'r') as f:
    data = json.load(f)

# Upload to Firestore
print(f"Uploading {len(data)} samples to Firestore...")
for i, sample in enumerate(data):
    # Convert ISO date string to datetime if needed
    if 'createdAt' in sample and isinstance(sample['createdAt'], str):
        sample['createdAt'] = datetime.fromisoformat(sample['createdAt'])
    
    db.collection('workoutFeedback').add(sample)
    
    if (i + 1) % 50 == 0:
        print(f"Uploaded {i + 1} samples...")

print("Upload complete!")
