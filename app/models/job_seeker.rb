class JobSeeker < ApplicationRecord
    has_one :profile, as: :user
    has_many :skills, through: :profile

    has_many :add_events
    has_many :events, through: :add_events

    def recruiters
        self.events.collect{|event| event.recruiter}
    end

    def view_skills
        self.skills.collect{|skills| skills.name}
    end

    def add_skill(name, level)
        Skill.create(profile_id: self.profile.id, name: name, level: level)
    end

    def delete_skill(name)
        self.skills.find_by(name: name).destroy
    end

    def view_events
        self.events.collect{|event| event.description}
    end

    def delete_events(event)
        self.events.find_by(description: event).destroy
    end

    def edit_location(location)
        self.update(location: location)
    end

    def find_and_add_event(company_name, date)
        date = date.to_s
        event_id = Recruiter.find_by(company_name: company_name).events.find_by(event_date: DateTime.parse(date)).id
        AddEvent.create(event_id: event_id, job_seeker_id: self.id)
    end



    def all_matching_recruiters
        #main logic
        #look into all the skill name of this job_seeker, collect them in to an array =>job_seeker_skill_names
        #look into the skill instances of all the recruiters are looking for, store them into an array => all_recruiter_skills_flattened
        #loop thru both arrays and select the match base on skill_name, store the result into an array => matching
        #store all the profile_id of the matching result in to an array => 
        #sort  by count-of-occurrences => sorted_
        #use the sorted_ to find all the matching recruiter instances.

        job_seeker_skill_names = self.view_skills #=> array of skill_name

        all_recruiter_skills_flattened = Recruiter.all.map{|recruiter| recruiter.skills}.flatten #=> return an arr of skill instance
        
        matching = job_seeker_skill_names.map{|job_seeker_skill_name| 
            all_recruiter_skills_flattened.select{
                |recruiter_skill| recruiter_skill.name == job_seeker_skill_name 
            }
        }.flatten #=> return all the matching skill instance with profile_id

        matching_profile_id_arr = matching.map {|match| match.profile_id}

        #sort array by count-of-occurrences : https://stackoverflow.com/questions/10842210/sort-and-display-items-by-count-of-occurrences/10842419
        sorted_matching_profile_id_arr = matching_profile_id_arr.group_by{|x| x}.sort_by{|k, v| -v.size}.map(&:first)

        sorted_matching_recruitor_arr = sorted_matching_profile_id_arr.map{
            |matching_profile_id| Recruiter.all.select{
                |recruiter| recruiter.profile.id == matching_profile_id
            }
        }.flatten #=>return the array of matching recruiter instance

    end

    def all_matching_recruiter_company_and_name
        self.all_matching_recruiters.map{|matching_recruiter| 
            "#{matching_recruiter.company_name}, #{matching_recruiter.name}"
        }
    end

    def all_matching_recruiter_company_name
        self.all_matching_recruiters.map{|matching_recruiter| matching_recruiter.company_name}
    end

    def all_matching_events #just incase we need it
        self.all_matching_recruiters.map{|matching_recruiter| matching_recruiter.events}.flatten.map{|event| {event_date: event.event_date, location: event.location, company_name: event.recruiter.company_name, name: event.recruiter.name}}
    end

    def matching_events_in_my_city #just incase we need it
        self.all_matching_events.select{|event| event.include?(self.location)}
    end

    def all_matching_events_for_front_end
        me = self.all_matching_recruiters.map{|matching_recruiter| matching_recruiter.events}.flatten
        ge = self.events
        me_hash = Hash.new
        me.map{|m| me_hash[m.id] = m}
        ge.map{|g| if me_hash.has_key?(g.id) 
                        me_hash.delete(g.id)
                   end
        }
        me_hash.values
    end

    def create_profile
        Profile.create(user_id: self.id, user_type: "JobSeeker")
    end

    def all_matching_recruiters_with_skills
        self.all_matching_recruiters.map{|r|
            {name: r.name, company_name: r.company_name, email: r.email, id:r.id, location:r.location, logo:r.logo, username:r.username, skills: r.skills }
        }
    end

end

