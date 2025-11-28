"""
Synthetic Workout Feedback Data Generator
Generates realistic training data for the Workout AI ML model
"""

import random
import json
import csv
from datetime import datetime, timedelta

class WorkoutDataGenerator:
    def __init__(self):
        self.fitness_levels = ['Beginner', 'Intermediate', 'Advanced', 'Professional']
        self.durations = ['Day', 'Week', 'Month', 'Year']
        self.goals = [
            'Weight loss', 'Muscle building', 'General fitness',
            'Endurance training', 'Strength training', 'Flexibility'
        ]
        
    def generate_correlated_sample(self):
        """Generate a realistic workout feedback sample with correlations"""
        
        # User characteristics
        age = random.randint(18, 65)
        weight = random.uniform(50, 120)
        height = random.uniform(150, 200)
        fitness_level = random.choice(self.fitness_levels)
        duration = random.choice(self.durations)
        
        # Calculate BMI for realism
        bmi = weight / ((height / 100) ** 2)
        
        # Base completion rate with realistic correlations
        base_completion = 0.75
        
        # Fitness level affects completion
        if fitness_level == 'Beginner':
            base_completion -= 0.15
        elif fitness_level in ['Advanced', 'Professional']:
            base_completion += 0.10
        
        # Duration affects completion (longer is harder)
        duration_difficulty = {
            'Day': 0.15,
            'Week': 0.05,
            'Month': -0.10,
            'Year': -0.25
        }
        base_completion += duration_difficulty[duration]
        
        # Age affects completion (peak performance 25-35)
        if age < 25 or age > 50:
            base_completion -= 0.08
        
        # BMI affects completion (unhealthy ranges reduce completion)
        if bmi < 18.5 or bmi > 30:
            base_completion -= 0.10
        
        # Add random variance
        completion_rate = max(0.1, min(1.0, base_completion + random.uniform(-0.15, 0.15)))
        
        # Difficulty rating correlates with fitness level and completion
        if fitness_level == 'Beginner':
            difficulty_rating = random.randint(3, 5)
        elif fitness_level == 'Professional':
            difficulty_rating = random.randint(1, 3)
        else:
            difficulty_rating = random.randint(2, 4)
        
        # Effectiveness correlates with completion rate
        if completion_rate >= 0.8:
            effectiveness_rating = random.randint(4, 5)
        elif completion_rate >= 0.6:
            effectiveness_rating = random.randint(3, 5)
        elif completion_rate >= 0.4:
            effectiveness_rating = random.randint(2, 4)
        else:
            effectiveness_rating = random.randint(1, 3)
        
        # Injury probability (higher with extreme conditions)
        injury_probability = 0.03  # Base 3%
        if fitness_level == 'Beginner' and duration in ['Month', 'Year']:
            injury_probability = 0.12  # Beginners more likely injured on long programs
        if age > 55:
            injury_probability += 0.05
        if difficulty_rating >= 4:
            injury_probability += 0.03
        
        injury_occurred = random.random() < injury_probability
        
        # Days completed based on completion rate and duration
        duration_days = {'Day': 1, 'Week': 7, 'Month': 30, 'Year': 365}
        days_completed = int(completion_rate * duration_days[duration])
        
        return {
            'userId': f'synthetic_user_{random.randint(1, 10000)}',
            'workoutPlanId': f'plan_{random.randint(1, 100000)}',
            'age': age,
            'weight': round(weight, 1),
            'height': round(height, 1),
            'fitnessLevel': fitness_level,
            'workoutDuration': duration,
            'completionRate': round(completion_rate, 2),
            'difficultyRating': difficulty_rating,
            'effectivenessRating': effectiveness_rating,
            'injuryOccurred': injury_occurred,
            'daysCompleted': days_completed,
            'feedbackText': self.generate_feedback_text(completion_rate, effectiveness_rating, injury_occurred),
            'createdAt': self.random_date()
        }
    
    def generate_feedback_text(self, completion_rate, effectiveness_rating, injury_occurred):
        """Generate realistic feedback text"""
        if injury_occurred:
            return random.choice([
                'Had to stop due to injury',
                'Too intense, caused pain',
                'Not suitable for my level',
                'Experienced joint pain'
            ])
        elif completion_rate >= 0.8:
            return random.choice([
                'Great workout, felt amazing!',
                'Perfect difficulty level',
                'Seeing great results',
                'Would recommend to others',
                'Challenging but doable'
            ])
        elif completion_rate >= 0.5:
            return random.choice([
                'Good but could be better',
                'Some exercises too difficult',
                'Needed more rest days',
                'Partially completed'
            ])
        else:
            return random.choice([
                'Too difficult for my level',
                'Could not maintain schedule',
                'Need easier alternatives',
                'Time commitment too high'
            ])
    
    def random_date(self):
        """Generate random date within last 6 months"""
        days_ago = random.randint(0, 180)
        date = datetime.now() - timedelta(days=days_ago)
        return date.isoformat()
    
    def generate_dataset(self, num_samples=500):
        """Generate complete dataset"""
        dataset = []
        for i in range(num_samples):
            sample = self.generate_correlated_sample()
            dataset.append(sample)
            
            if (i + 1) % 100 == 0:
                print(f'Generated {i + 1} samples...')
        
        return dataset
    
    def save_to_json(self, dataset, filename='workout_dataset.json'):
        """Save dataset to JSON file"""
        with open(filename, 'w') as f:
            json.dump(dataset, f, indent=2)
        print(f'Saved {len(dataset)} samples to {filename}')
    
    def save_to_csv(self, dataset, filename='workout_dataset.csv'):
        """Save dataset to CSV file"""
        if not dataset:
            return
        
        fieldnames = list(dataset[0].keys())
        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(dataset)
        print(f'Saved {len(dataset)} samples to {filename}')
    
    def print_statistics(self, dataset):
        """Print dataset statistics"""
        print("\n=== Dataset Statistics ===")
        print(f"Total Samples: {len(dataset)}")
        
        avg_completion = sum(d['completionRate'] for d in dataset) / len(dataset)
        print(f"Average Completion Rate: {avg_completion:.2%}")
        
        injury_count = sum(1 for d in dataset if d['injuryOccurred'])
        print(f"Injury Rate: {injury_count/len(dataset):.2%}")
        
        fitness_dist = {}
        for d in dataset:
            level = d['fitnessLevel']
            fitness_dist[level] = fitness_dist.get(level, 0) + 1
        print(f"Fitness Level Distribution: {fitness_dist}")
        
        duration_dist = {}
        for d in dataset:
            dur = d['workoutDuration']
            duration_dist[dur] = duration_dist.get(dur, 0) + 1
        print(f"Duration Distribution: {duration_dist}")
        
        print("\nAge Range:", 
              f"{min(d['age'] for d in dataset)} - {max(d['age'] for d in dataset)}")
        print("Weight Range:", 
              f"{min(d['weight'] for d in dataset):.1f} - {max(d['weight'] for d in dataset):.1f} kg")
        print("Height Range:", 
              f"{min(d['height'] for d in dataset):.1f} - {max(d['height'] for d in dataset):.1f} cm")


def main():
    """Main function to generate and save dataset"""
    print("Workout AI - Synthetic Data Generator")
    print("=" * 40)
    
    generator = WorkoutDataGenerator()
    
    # Generate dataset
    num_samples = 500
    print(f"\nGenerating {num_samples} synthetic workout feedback samples...")
    dataset = generator.generate_dataset(num_samples)
    
    # Save to both formats
    generator.save_to_json(dataset)
    generator.save_to_csv(dataset)
    
    # Print statistics
    generator.print_statistics(dataset)
    
    print("\n✓ Data generation complete!")
    print("\nYou can now:")
    print("1. Import this data into Firebase using the Firebase Admin SDK")
    print("2. Use the CSV file for analysis in Excel/Python")
    print("3. Load the JSON file directly into your app for testing")


if __name__ == '__main__':
    main()
