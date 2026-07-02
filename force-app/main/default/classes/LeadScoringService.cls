public with sharing class LeadScoringService {

    // Scoring weights
    private static final Map<String, Integer> INDUSTRY_SCORE = new Map<String, Integer>{
        'Technology'       => 20,
        'Financial Services' => 18,
        'Healthcare'       => 15,
        'Manufacturing'    => 12,
        'Retail'           => 8
    };

    private static final Map<String, Integer> TITLE_SCORE = new Map<String, Integer>{
        'CEO'   => 25, 'CTO'   => 25, 'CFO'   => 20,
        'VP'    => 18, 'Director' => 15, 'Manager' => 10
    };

    private static final Map<String, Integer> EMPLOYEE_SCORE = new Map<String, Integer>{
        '1,001 to 5,000'  => 15,
        '5,001 to 10,000' => 20,
        'More than 10,000'=> 25,
        '501 to 1,000'    => 10,
        '201 to 500'      => 8
    };

    @InvocableMethod(label='Score Leads' description='Calculate lead score based on firmographic data')
    public static List<LeadScoreResult> scoreLeads(List<Id> leadIds) {
        List<Lead> leads = [
            SELECT Id, Industry, Title, NumberOfEmployees, LeadSource,
                   Email, Phone, Website, AnnualRevenue
            FROM Lead
            WHERE Id IN :leadIds
        ];

        List<LeadScoreResult> results = new List<LeadScoreResult>();
        List<Lead> toUpdate = new List<Lead>();

        for (Lead l : leads) {
            Integer score  = computeScore(l);
            String  grade  = getGrade(score);
            String  rating = gradeToRating(grade);

            toUpdate.add(new Lead(
                Id          = l.Id,
                Rating      = rating,
                Description = 'Lead Score: ' + score + ' | Grade: ' + grade
            ));

            results.add(new LeadScoreResult(l.Id, score, grade));
        }

        if (!toUpdate.isEmpty()) update toUpdate;

        return results;
    }

    private static Integer computeScore(Lead l) {
        Integer score = 0;

        // Industry score
        if (l.Industry != null && INDUSTRY_SCORE.containsKey(l.Industry)) {
            score += INDUSTRY_SCORE.get(l.Industry);
        }

        // Title score
        if (l.Title != null) {
            for (String keyword : TITLE_SCORE.keySet()) {
                if (l.Title.containsIgnoreCase(keyword)) {
                    score += TITLE_SCORE.get(keyword);
                    break;
                }
            }
        }

        // Company size score
        String empRange = getEmployeeRange(l.NumberOfEmployees);
        if (EMPLOYEE_SCORE.containsKey(empRange)) {
            score += EMPLOYEE_SCORE.get(empRange);
        }

        // Completeness bonus
        if (String.isNotBlank(l.Email))   score += 5;
        if (String.isNotBlank(l.Phone))   score += 5;
        if (String.isNotBlank(l.Website)) score += 5;
        if (l.AnnualRevenue != null && l.AnnualRevenue > 1000000) score += 10;

        // Lead source bonus
        if (l.LeadSource == 'Web')            score += 5;
        if (l.LeadSource == 'Partner Referral') score += 10;

        return Math.min(score, 100);
    }

    private static String getGrade(Integer score) {
        if (score >= 80) return 'A';
        if (score >= 60) return 'B';
        if (score >= 40) return 'C';
        return 'D';
    }

    private static String gradeToRating(String grade) {
        if (grade == 'A') return 'Hot';
        if (grade == 'B') return 'Warm';
        return 'Cold';
    }

    private static String getEmployeeRange(Integer count) {
        if (count == null)           return '';
        if (count > 10000)           return 'More than 10,000';
        if (count > 5000)            return '5,001 to 10,000';
        if (count > 1000)            return '1,001 to 5,000';
        if (count > 500)             return '501 to 1,000';
        if (count > 200)             return '201 to 500';
        return 'Under 200';
    }

    public class LeadScoreResult {
        @InvocableVariable public Id     leadId;
        @InvocableVariable public Integer score;
        @InvocableVariable public String  grade;

        public LeadScoreResult(Id leadId, Integer score, String grade) {
            this.leadId = leadId;
            this.score  = score;
            this.grade  = grade;
        }
    }
}
