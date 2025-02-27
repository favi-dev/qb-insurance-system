local Translations = {
    error = {
        not_enough_money = "ليس لديك ما يكفي من المال",
        already_insured = "هذه المركبة مؤمنة بالفعل",
        no_insurance = "ليس لديك تأمين على هذا",
        claim_in_progress = "لديك مطالبة قيد المعالجة بالفعل",
        claim_rejected = "تم رفض مطالبتك بالتأمين",
        fraud_detected = "تم اكتشاف احتيال محتمل في التأمين",
        no_vehicle_nearby = "لا توجد مركبة قريبة",
        not_owner = "أنت لا تملك هذه المركبة"
    },
    success = {
        insurance_purchased = "تم شراء التأمين بنجاح",
        claim_submitted = "تم تقديم مطالبتك",
        claim_approved = "تمت الموافقة على مطالبتك بالتأمين",
        payment_received = "لقد تلقيت تعويض تأميني بقيمة $%{amount}"
    },
    info = {
        insurance_office = "مكتب التأمين",
        processing_claim = "جاري معالجة مطالبتك...",
        insurance_expired = "انتهت صلاحية تأمينك",
        monthly_fee = "تم خصم رسوم التأمين الشهرية بقيمة $%{amount}",
        insurance_menu = "خدمات التأمين",
        claim_investigation = "تتم مراجعة مطالبتك"
    },
    menu = {
        insurance_services = "خدمات التأمين",
        vehicle_insurance = "تأمين المركبات",
        property_insurance = "تأمين الممتلكات",
        health_insurance = "تأمين الصحة",
        file_claim = "تقديم مطالبة",
        view_policies = "عرض سياساتي",
        cancel_policy = "إلغاء البوليصة"
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})