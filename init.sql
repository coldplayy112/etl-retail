-- 0. Create ENUM for last_status
CREATE TYPE transaction_status AS ENUM (
  'COMPLETED',
  'PENDING',
  'CANCELLED',
  'REFUNDED'
);

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.retail_transactions (
    id SERIAL PRIMARY KEY,
    customer_id uuid NOT NULL,
    last_status transaction_status NULL,
    pos_origin text NULL,
    pos_destination text NULL,
    created_at timestamp DEFAULT now() NOT NULL,
    updated_at timestamp DEFAULT now() NULL,
    deleted_at timestamp NULL
);

-- 2. Lifecycle trigger function
CREATE OR REPLACE FUNCTION retail_transaction_lifecycle()
RETURNS trigger AS $$
BEGIN
    -- Always set created_at on insert
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := NOW();
    END IF;

    -- Always refresh updated_at
    NEW.updated_at := NOW();

    -- If last_status is COMPLETED, stamp deleted_at
    IF NEW.last_status = 'COMPLETED' THEN
        -- On insert, always set it
        IF TG_OP = 'INSERT' THEN
            NEW.deleted_at := NOW();
        -- On update, only set if it wasn’t already stamped
        ELSIF TG_OP = 'UPDATE' AND OLD.deleted_at IS NULL THEN
            NEW.deleted_at := NOW();
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach trigger
CREATE TRIGGER trg_retail_transaction_lifecycle
BEFORE INSERT OR UPDATE ON public.retail_transactions
FOR EACH ROW
EXECUTE FUNCTION retail_transaction_lifecycle();

-- 4. Insert dummy data
INSERT INTO public.retail_transactions (
    customer_id, last_status, pos_origin, pos_destination, created_at, updated_at
)
VALUES
(gen_random_uuid(), 'COMPLETED', 'NYC_01', 'LAX_05', now() - interval '2 days', now()),
(gen_random_uuid(), 'PENDING',   'CHI_02', 'SEA_01', now() - interval '1 day',  now()),
(gen_random_uuid(), 'CANCELLED', 'MIA_01', 'DAL_03', now() - interval '5 hours', now()),
(gen_random_uuid(), 'COMPLETED', 'SFO_04', 'PHX_02', now(), now()),
(gen_random_uuid(), 'COMPLETED', 'BOS_01', 'NYC_02', now() - interval '3 days', now()),
(gen_random_uuid(), 'REFUNDED',  'ATL_05', 'MIA_02', now() - interval '4 days', now()),
(gen_random_uuid(), 'PENDING',   'DEN_01', 'SLC_01', now() - interval '12 hours', now()),
(gen_random_uuid(), 'COMPLETED', 'HOU_03', 'AUS_01', now() - interval '6 hours', now()),
(gen_random_uuid(), 'COMPLETED', 'PHL_02', 'DC_01',  now() - interval '1 week', now()),
(gen_random_uuid(), 'CANCELLED', 'DET_01', 'CHI_05', now() - interval '2 weeks', now()),
(gen_random_uuid(), 'COMPLETED', 'SAN_01', 'SFO_02', now() - interval '3 hours', now()),
(gen_random_uuid(), 'PENDING',   'SEA_02', 'POR_01', now() - interval '1 hour',  now()),
(gen_random_uuid(), 'COMPLETED', 'LAS_05', 'LAX_01', now() - interval '20 mins', now()),
(gen_random_uuid(), 'REFUNDED',  'ORL_02', 'MIA_05', now() - interval '10 days', now()),
(gen_random_uuid(), 'COMPLETED', 'NAS_01', 'CHA_02', now() - interval '45 mins', now()),
(gen_random_uuid(), 'PENDING',   'CLE_03', 'PIT_01', now() - interval '8 hours', now()),
(gen_random_uuid(), 'COMPLETED', 'MIN_01', 'MIL_04', now() - interval '2 days', now()),
(gen_random_uuid(), 'COMPLETED', 'SLC_02', 'DEN_05', now() - interval '18 hours', now()),
(gen_random_uuid(), 'CANCELLED', 'OKC_01', 'DAL_01', now() - interval '30 mins', now()),
(gen_random_uuid(), 'COMPLETED', 'PHX_01', 'SAN_03', now() - interval '4 days', now());

-- END OF SCRIPT.