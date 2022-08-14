import csv
import math
import matplotlib.pyplot as plt
from wordcloud import WordCloud, STOPWORDS

# Hi, welcome to my program. This file contains code that runs 
# on data found from the Disproportionality Analysis. 
# It analysis the data to to create a word cloud that displays 
# the ATC codes of drugs based on how high the sum of their Omega 
# values is from all their interactions in a drug pair.

def get_data():
    with open('interaction.csv', 'r') as file:
        codes = csv.reader(file)
        words = {}
        for row in codes:
            if row[0] not in words:
                words[row[0]] = 0
            if row[1] not in words:
                words[row[1]] = 0
            # saves omega score as value of the dictionary 
            if row[2] != 'OR' and row[2] != "NaN":
                words[row[0]] += float(row[3])
                words[row[1]] += float(row[3])
    return words

def create_text():
    info = get_data()
    text = ""
    for code in info:
        if math.isinf(info[code]):
            quant = int(1000)
        else:
            quant = int(info[code])
        # number of occurrences of the code in text is proportional to Omega sum
        for _ in range(quant):
            text += code
            text += " "
    return text



def plot_cloud(wordcloud):
    # Set figure size
    plt.figure(figsize=(20, 15))
    # Display image
    plt.imshow(wordcloud) 
    # No axis details
    plt.axis("off")

text = create_text()
# Generate word cloud
wordcloud = WordCloud(width = 2300, height = 1200, random_state=1, background_color='salmon', colormap='Pastel1', collocations=False, stopwords = STOPWORDS).generate(text)
# Plot
plot_cloud(wordcloud)
