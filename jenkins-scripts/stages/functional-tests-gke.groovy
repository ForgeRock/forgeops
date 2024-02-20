/*
 * Copyright 2024 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// functional-tests-gke.groovy
void runStage() {
    commonModule.runGuillotine(null, 'functional', 'GKE', '--keywords FUNCTIONAL')
}

return this
