
# coding: utf-8

from sklearn.ensemble import GradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from six.moves import cPickle as pickle
import pandas as pd


# Preprocessing functions

def preprocessing_fillna(df, col_names):
    for c in col_names:
        df[c] = df[c].fillna(df[c].mean())
    df = df.fillna(-999)
    return df
    
def ohe_transform(df, col_name, ohe):
    encoded_col = ohe.transform(df[col_name].values.reshape(-1, 1))
    tmp = pd.DataFrame(encoded_col, columns=[col_name + str(i) for i in range(encoded_col.shape[1])], index = df.index)
    df = pd.concat([df, tmp], axis = 1)
    df = df.drop([col_name], axis = 1)
    return df


# Read model from pickle

pickle_file = 'model.pickle'

with open(pickle_file, 'rb') as f:
    save = pickle.load(f)
    model = save['model']
    ohe_dow = save['ohe_dow']
    print('Model Loaded')


# Prediction

# Считываем данные для предсказания, которые выдает запрос
features = pd.read_csv('input.csv', header = 0, index_col=[0,1])


features = features.drop(['worked', 'days_since_last_order'], axis=1)

# Preprocessing
features = preprocessing_fillna(features, ['age'])
features = ohe_transform(features, 'dow', ohe_dow)


# Prediction
df = pd.DataFrame(index=features.index, columns=['worked'])
df['worked'] = model.predict_proba(features)[:,1]
df.to_csv('output.csv')
print('Done')




