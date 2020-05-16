import codecs, json
import pandas as pd

df = pd.read_json('trump_tweets.json', encoding='utf-8')
df.to_csv("trump_tweets.csv", encoding="utf-8")






#with codecs.open("trump_tweets2.json", "r", "utf-8") as f:
#    tweets = json.load(f, encoding="utf-8")

