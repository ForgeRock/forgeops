/*
 * Copyright 2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// functional-tests-gke.groovy
void runStage() {
    commonModule.runGuillotine(null, 'functional', 'GKE', '--keywords RELEASE')
}

return this
