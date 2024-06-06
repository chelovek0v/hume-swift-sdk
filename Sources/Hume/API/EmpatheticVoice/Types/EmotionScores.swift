//
//  EmotionScores.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct EmotionScores: Codable {
    let admiration: Double
    let adoration: Double
    let aestheticAppreciation: Double
    let amusement: Double
    let anger: Double
    let anxiety: Double
    let awe: Double
    let awkwardness: Double
    let boredom: Double
    let calmness: Double
    let concentration: Double
    let confusion: Double
    let contemplation: Double
    let contempt: Double
    let contentment: Double
    let craving: Double
    let desire: Double
    let determination: Double
    let disappointment: Double
    let disgust: Double
    let distress: Double
    let doubt: Double
    let ecstasy: Double
    let embarrassment: Double
    let empathicPain: Double
    let entrancement: Double
    let envy: Double
    let excitement: Double
    let fear: Double
    let guilt: Double
    let horror: Double
    let interest: Double
    let joy: Double
    let love: Double
    let nostalgia: Double
    let pain: Double
    let pride: Double
    let realization: Double
    let relief: Double
    let romance: Double
    let sadness: Double
    let satisfaction: Double
    let shame: Double
    let surpriseNegative: Double
    let surprisePositive: Double
    let sympathy: Double
    let tiredness: Double
    let triumph: Double
    
    
    private enum CodingKeys: String, CodingKey {
        case admiration = "Admiration",
             adoration = "Adoration",
             aestheticAppreciation = "Aesthetic Appreciation",
             amusement = "Amusement",
             anger = "Anger",
             anxiety = "Anxiety",
             awe = "Awe",
             awkwardness = "Awkwardness",
             boredom = "Boredom",
             calmness = "Calmness",
             concentration = "Concentration",
             confusion = "Confusion",
             contemplation = "Contemplation",
             contempt = "Contempt",
             contentment = "Contentment",
             craving = "Craving",
             desire = "Desire",
             determination = "Determination",
             disappointment = "Disappointment",
             disgust = "Disgust",
             distress = "Distress",
             doubt = "Doubt",
             ecstasy = "Ecstasy",
             embarrassment = "Embarrassment",
             empathicPain = "Empathic Pain",
             entrancement = "Entrancement",
             envy = "Envy",
             excitement = "Excitement",
             fear = "Fear",
             guilt = "Guilt",
             horror = "Horror",
             interest = "Interest",
             joy = "Joy",
             love = "Love",
             nostalgia = "Nostalgia",
             pain = "Pain",
             pride = "Pride",
             realization = "Realization",
             relief = "Relief",
             romance = "Romance",
             sadness = "Sadness",
             satisfaction = "Satisfaction",
             shame = "Shame",
             surpriseNegative = "Surprise (negative)",
             surprisePositive = "Surprise (positive)",
             sympathy = "Sympathy",
             tiredness = "Tiredness",
             triumph = "Triumph"
    }
    
    public var topThree: [(String, Double)] {
        get {
            let slice = asPairs
                .sorted { score1, score2 in score1.1 >= score2.1 }
                .prefix(3)
            
            return Array(slice)
        }
    }
    
    var asPairs: [(String, Double)] {
        get {
            [
                ("Admiration", admiration),
                ("Adoration", adoration),
                ("Aesthetic Appreciation", aestheticAppreciation),
                ("Amusement", amusement),
                ("Anger", anger),
                ("Anxiety", anxiety),
                ("Awe", awe),
                ("Awkwardness", awkwardness),
                ("Boredom", boredom),
                ("Calmness", calmness),
                ("Concentration", concentration),
                ("Confusion", confusion),
                ("Contemplation", contemplation),
                ("Contempt", contempt),
                ("Contentment", contentment),
                ("Craving", craving),
                ("Desire", desire),
                ("Determination", determination),
                ("Disappointment", disappointment),
                ("Disgust", disgust),
                ("Distress", distress),
                ("Doubt", doubt),
                ("Ecstasy", ecstasy),
                ("Embarrassment", embarrassment),
                ("Empathic Pain", empathicPain),
                ("Entrancement", entrancement),
                ("Envy", envy),
                ("Excitement", excitement),
                ("Fear", fear),
                ("Guilt", guilt),
                ("Horror", horror),
                ("Interest", interest),
                ("Joy", joy),
                ("Love", love),
                ("Nostalgia", nostalgia),
                ("Pain", pain),
                ("Pride", pride),
                ("Realization", realization),
                ("Relief", relief),
                ("Romance", romance),
                ("Sadness", sadness),
                ("Satisfaction", satisfaction),
                ("Shame", shame),
                ("Surprise (negative)", surpriseNegative),
                ("Surprise (positive)", surprisePositive),
                ("Sympathy", sympathy),
                ("Tiredness", tiredness),
                ("Triumph", triumph)
            ]
        }
    }
}
