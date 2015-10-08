$(document).ready(function() {


    $('#thesis_degreeName').change(
        function() {
            var degree_type;

            switch (this.value) {
                case 'DPhil':
                case 'PhD':
                    degree_type = 'Doctoral'
                    break;
                case 'MSc':
                case 'MSc by Research':
                case 'MPhil':
                case 'M.St.':
                case 'MLitt':
                    degree_type = 'Masters'
                    break;
                case 'BLitt':
                case 'BPhil':
                case 'Bachelor of Divinity (B.D.)':
                    degree_type = "Bachelors";
                    break;
                default:
                    degree_type = "Unknown";
            }

            $('#thesis_degreeType').val(degree_type);
        });

    $('#thesis_hasThirdPartyCopyrightMaterial_yes').click(
        function() {
            $('#has_copyright_material').removeClass("hidden-form");
            $('#hasnt_copyright_material').addClass("hidden-form");
            // if (this.checked && this.value == 'Yes') {
            // note that, as per comments, the 'changed'
            // <input> will *always* be checked, as the change
            // event only fires on checking an <input>, not
            // on un-checking it.
            // append goes here
        }
    );
    $('#thesis_hasThirdPartyCopyrightMaterial_no').click(
        function() {
            $('#hasnt_copyright_material').removeClass("hidden-form");
            $('#has_copyright_material').addClass("hidden-form");
        }
    );

    $('#thesis_dispensationFromConsultation_yes').click(
        function() {
            $('#has_dispensation').removeClass("hidden-form");
        }
    );
    $('#thesis_dispensationFromConsultation_no').click(
        function() {
            $('#has_dispensation').addClass("hidden-form");
        }
    );
    $('#thesis_dispensationSelect_end_date').click(
        function() {
            $('#has_dispensation_end_date').removeClass("hidden-form");
            $('#has_dispensation_period').addClass("hidden-form");
        }
    );
    $('#thesis_dispensationSelect_period').click(
        function() {
            $('#has_dispensation_end_date').addClass("hidden-form");
            $('#has_dispensation_period').removeClass("hidden-form");
        }
    );
    $('#thesis_dispensationSelect_permanent').click(
        function() {
            $('#has_dispensation_end_date').addClass("hidden-form");
            $('#has_dispensation_period').addClass("hidden-form");
        }
    );    

    $('#thesis_dispensationPeriodYears').click(
        function() {
            $('#dispensation_years_count').html(this.value);
        }
    );

    $('#thesis_dispensationPeriodMonths').click(
        function() {
            $('#dispensation_months_count').html(this.value);
        }
    );



});