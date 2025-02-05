Vue
    .createApp({
        data() {
            return register_data;
        },
        computed: {
            can_register_teams() {
                return this.org && ( this.profile_coach == 1 || this.roles.indexOf('Coach') != -1 );
            },
        },
        watch: {
            $data: {
                handler: function () {
                    if ( ! this.changed ) this.nav_content_align();
                    this.changed = 1;
                },
                deep: true
            }
        },
        methods : {
            add_team : function () {
                var team = [];
                this.teams.push(team);
                this.add_quizzer(team);
                this.nav_content_align();
            },

            add_quizzer : function (team) {
                var quizzer = { attend : true, house : true, lunch : true };
                team.push(quizzer);
                this.add_watch(quizzer);
                this.nav_content_align();
            },

            add_nonquizzer : function (team) {
                var nonquizzer = { house : true, lunch : true };
                this.nonquizzers.push(nonquizzer);
                this.nav_content_align();
            },

            add_watch : function (record) {
                this.$watch(
                    function () {
                        return record.attend;
                    },
                    ( function () {
                        var _record = record;

                        return function (attend) {
                            if ( attend == null ) return;
                            _record.house  = attend;
                            _record.lunch  = attend;
                            _record.driver = null;
                        }
                    } )()
                );
            },

            nav_content_align : function () {
                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            },

            reorder : function ( direction, person_index, team_index ) {
                var element = this.teams[team_index].splice( person_index, 1 )[0];

                if ( direction == -1 ) {
                    if ( person_index != 0 ) {
                        this.teams[team_index].splice( person_index - 1, 0, element );
                    }
                    else {
                        var target = team_index - 1;
                        if ( target < 0 ) target = this.teams.length - 1;
                        this.teams[target].push(element);
                    }
                }
                else if ( direction == 1 ) {
                    if ( person_index != this.teams[team_index].length ) {
                        this.teams[team_index].splice( person_index + 1, 0, element );
                    }
                    else {
                        var target = team_index + 1;
                        if ( target > this.teams.length - 1 ) target = 0;
                        this.teams[target].unshift(element);
                    }
                }

                if ( this.teams[team_index].length == 0 ) this.teams.splice( team_index, 1 );
            },

            delete_quizzer : function ( person_index, team_index ) {
                var registration_id = this.teams[team_index][person_index].registration_id || 0;
                if (registration_id) this.deleted_persons.push(registration_id);

                this.teams[team_index].splice( person_index, 1 );
                if ( this.teams[team_index].length == 0 ) this.teams.splice( team_index, 1 );

                this.nav_content_align();
            },

            delete_nonquizzer : function (person_index) {
                this.nonquizzers.splice( person_index, 1 );
                this.nav_content_align();
            },

            save_registration : function () {
                var register = document.getElementById("register_save");
                register.elements[0].value = JSON.stringify(register_data);
                register.submit();
            }
        },

        mounted : function () {
            for ( var t = 0; t < this.teams.length; t++ ) {
                for ( var q = 0; q < this.teams[t].length; q++ ) {
                    this.add_watch( this.teams[t][q] );
                }
            }

            this.nav_content_align();
        }
    })
    .mount('#register');
